#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>

#ifndef __constant_htons
#define __constant_htons(x) __builtin_bswap16(x)
#endif
#ifndef __constant_ntohs
#define __constant_ntohs(x) __builtin_bswap16(x)
#endif

// Max UDP packets per second per IP (Generous for games, but stops floods)
#define MAX_UDP_PPS 5000
#define ONE_SEC_NS 1000000000ULL

struct ip_state {
    __u64 last_time;
    __u64 count;
};

// Map to track IP packet rates using an LRU cache (evicts old IPs automatically)
struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 100000); // Track up to 100,000 concurrent IPs
    __type(key, __u32);
    __type(value, struct ip_state);
} rate_limit_map SEC(".maps");

SEC("xdp")
int xdp_prog(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    struct ethhdr *eth = data;
    if (data + sizeof(struct ethhdr) > data_end)
        return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(struct ethhdr);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    // Only apply rate limiting and frag dropping to UDP
    if (ip->protocol != IPPROTO_UDP)
        return XDP_PASS;

    // Drop fragmented UDP packets (only if it's not the first fragment)
    // Legit large packets might fragment, but offset > 0 is common in floods
    if (ip->frag_off & __constant_htons(IP_OFFSET)) {
        return XDP_DROP;
    }

    struct udphdr *udp = (void *)ip + (ip->ihl * 4);
    if ((void *)(udp + 1) > data_end)
        return XDP_PASS;

    // IP Rate Limiting Logic (Anti-Spoofing / Volumetric Flood mitigation)
    __u32 src_ip = ip->saddr;
    __u64 now = bpf_ktime_get_ns();
    
    struct ip_state *state = bpf_map_lookup_elem(&rate_limit_map, &src_ip);
    if (state) {
        if (now - state->last_time > ONE_SEC_NS) {
            // Time window expired, reset counter
            state->count = 1;
            state->last_time = now;
        } else {
            state->count++;
            if (state->count > MAX_UDP_PPS) {
                // Rate limit exceeded, drop the packet
                return XDP_DROP;
            }
        }
    } else {
        // First time seeing this IP
        struct ip_state new_state = { .last_time = now, .count = 1 };
        bpf_map_update_elem(&rate_limit_map, &src_ip, &new_state, BPF_ANY);
    }

    // Drop unusually large UDP packets (likely amplification like Memcached/NTP)
    if (__constant_ntohs(ip->tot_len) > 1200) {
        return XDP_DROP;
    }

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
